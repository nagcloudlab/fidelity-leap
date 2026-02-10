import { CanDeactivateFn } from '@angular/router';

export const productListGuardGuard: CanDeactivateFn<unknown> = (component, currentRoute, currentState, nextState) => {
  return confirm('Do you want to leave the product list page?');
};
