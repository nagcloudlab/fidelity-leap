import { TestBed } from '@angular/core/testing';
import { CanActivateFn } from '@angular/router';

import { cartViewGuardGuard } from './cart-view-guard-guard';

describe('cartViewGuardGuard', () => {
  const executeGuard: CanActivateFn = (...guardParameters) => 
      TestBed.runInInjectionContext(() => cartViewGuardGuard(...guardParameters));

  beforeEach(() => {
    TestBed.configureTestingModule({});
  });

  it('should be created', () => {
    expect(executeGuard).toBeTruthy();
  });
});
