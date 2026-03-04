export const validStartAndEndDate = (startDate, endDate) => {
  const start = new Date(startDate);
  const end = new Date(endDate);
  const today = new Date();

  if (isNaN(start) || isNaN(end)) return false;

  if (end < start) return false;

  if (start > today || end > today) return false;

  const maxValidDate = new Date(start);
  maxValidDate.setFullYear(start.getFullYear() + 1);

  return end <= maxValidDate;
};

export const validAccountNumber = (accountNumber) => {
  const account = accountNumber.trim();

  const newAccountPattern = /^(65|67|64|61)\d{7}$/;

  const oldAccountPattern = /^70\d{11}$/;
  
  return newAccountPattern.test(account) || oldAccountPattern.test(account);
};