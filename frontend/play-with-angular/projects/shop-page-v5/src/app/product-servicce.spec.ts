import { TestBed } from '@angular/core/testing';

import { ProductServicce } from './product-servicce';

describe('ProductServicce', () => {
  let service: ProductServicce;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(ProductServicce);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
