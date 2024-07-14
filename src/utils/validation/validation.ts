import { ErrorMessage } from "./validation.types";

export const validateEmail = (email: string): ErrorMessage | undefined => {
  if (!email) {
    return "Email is required";
  }

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return "Please enter a valid email";
  }
};

export const validatePassword = (password: string): ErrorMessage | undefined => {
  if (!password) {
    return "Password is required";
  }

  if (password.length < 6) {
    return "Password must be at least 6 characters";
  }
};

export const validateName = (name: string): ErrorMessage | undefined => {
  if (!name) {
    return "Name is required";
  }

  if (name.length < 3) {
    return "Name must be at least 3 characters";
  }
};

export const validatePhoneNumber = (phoneNumber: string): ErrorMessage | undefined => {
  if (!phoneNumber) {
    return "Phone number is required";
  }

  if (!/^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$/.test(phoneNumber)) {
    return "Please enter a valid phone number";
  }
};

export const validateDate = (date: Date): ErrorMessage | undefined => {
  if (!date) {
    return "Date is required";
  }

  const currentDate = new Date();
  if (date > currentDate) {
    return "Date cannot be in the future";
  }
};

export const validateTime = (time: Date): ErrorMessage | undefined => {
  if (!time) {
    return "Time is required";
  }

  const currentTime = new Date();
  if (time > currentTime) {
    return "Time cannot be in the future";
  }
};

export const validateLocation = (location: string): ErrorMessage | undefined => {
  if (!location) {
    return "Location is required";
  }

  if (location.length < 3) {
    return "Location must be at least 3 characters";
  }
};