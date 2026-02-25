# frozen_string_literal: true

require "prawn"

class GeneratePdfService < ApplicationService
  attr_accessor :statement_text, :pdf_password

  MARGINS = [50, 10, 50, 30].freeze
  FONT_SIZE = 7.8
  LINE_HEIGHT_OFFSET = 6

  FONT_FAMILY = "CourierPrime"

  def run
    ensure_directory!

    Prawn::Document.generate(
      file_path,
      margin: MARGINS
    ) do |pdf|
      register_fonts(pdf)
      render_header(pdf)
      render_statement_body(pdf)
    end

    encrypted_path = encrypt_pdf!(file_path.to_s, pdf_password)

    File.delete(file_path) if File.exist?(file_path)

    encrypted_path
  end

  private

  def file_path
    @file_path ||= Rails.root.join(
      "storage",
      "statements",
      "statement_#{timestamp}.pdf"
    )
  end

  def ensure_directory!
    FileUtils.mkdir_p(File.dirname(file_path))
  end

  def register_fonts(pdf)
    pdf.font_families.update(
      FONT_FAMILY => {
        normal: font_path("CourierPrime-Regular.ttf"),
        bold: font_path("CourierPrime-Bold.ttf"),
        italic: font_path("CourierPrime-Italic.ttf"),
        bold_italic: font_path("CourierPrime-BoldItalic.ttf")
      }
    )
  end

  def render_header(pdf)
    pdf.repeat(:all) do
      pdf.bounding_box(
        [pdf.bounds.left, pdf.bounds.top + 40],
        width: pdf.bounds.width,
        height: 100
      ) do
        pdf.image logo_path,
                  width: 260,
                  position: :center

        pdf.move_up 10

        pdf.font(FONT_FAMILY, style: :bold) do
          pdf.text "ACCOUNT STATEMENT",
                   align: :center,
                   size: 12,
                   character_spacing: 1.2
        end
      end
    end
  end

  def render_statement_body(pdf)
    pdf.bounding_box(
      [pdf.bounds.left, pdf.bounds.top - 60],
      width: pdf.bounds.width,
      height: pdf.bounds.height - 60
    ) do
      setup_text_style(pdf)

      statement_text.to_s.each_line do |raw_line|
        render_line(pdf, raw_line.chomp)
      end
    end
  end

  def setup_text_style(pdf)
    pdf.font(FONT_FAMILY, size: FONT_SIZE)
    pdf.default_kerning = true
    pdf.fill_color "111111"
  end

  def render_line(pdf, raw_line)
    line_height = FONT_SIZE + LINE_HEIGHT_OFFSET
    line = preserve_leading_spaces(raw_line)

    pdf.start_new_page if pdf.cursor < line_height

    pdf.text_box(
      line,
      at: [pdf.bounds.left, pdf.cursor],
      width: pdf.bounds.width,
      height: line_height,
      overflow: :shrink_to_fit,
      disable_wrap_by_char: true
    )

    pdf.move_down line_height
  end

  def preserve_leading_spaces(line)
    line.sub(/\A +/) { |spaces| "\u00A0" * spaces.length }
  end

  def logo_path
    Rails.root.join("public", "images", "bnb_logo.png").to_s
  end

  def font_path(file_name)
    Rails.root.join("app/assets/fonts", file_name).to_s
  end

  def timestamp
    Time.current.strftime("%Y%m%d%H%M%S")
  end

  def encrypt_pdf!(path, password)
    raise "PDF password missing" if password.blank?

    encrypted = path.sub(/\.pdf\z/, "_secure.pdf")

    success = system(
      "/usr/bin/qpdf",
      "--encrypt", password, password, "256",
      "--",
      path,
      encrypted
    )

    raise "PDF encryption failed" unless success && File.exist?(encrypted)

    encrypted
  end
end

