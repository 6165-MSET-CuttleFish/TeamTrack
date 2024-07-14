export type ValidationResult = {
  isValid: boolean;
  message?: string;
};

export type ValidationFunction<T> = (value: T) => ValidationResult;

export type ValidationRules<T> = {
  [key: string]: ValidationFunction<T>;
};