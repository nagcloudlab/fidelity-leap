import { CanActivateFn } from '@angular/router';

export const cartViewGuardGuard: CanActivateFn = (route, state) => {
  // condition..
  let currentHour = new Date().getHours();
  if (currentHour > 9 || currentHour < 17) {
    alert('You can  view the cart between 9 AM and 5 PM.');
    return true;
  }
  return false;
};
