import { TestBed } from '@angular/core/testing';
import { CanDeactivateFn } from '@angular/router';

import { productListGuardGuard } from './product-list-guard-guard';

describe('productListGuardGuard', () => {
  const executeGuard: CanDeactivateFn<unknown> = (...guardParameters) => 
      TestBed.runInInjectionContext(() => productListGuardGuard(...guardParameters));

  beforeEach(() => {
    TestBed.configureTestingModule({});
  });

  it('should be created', () => {
    expect(executeGuard).toBeTruthy();
  });
});
