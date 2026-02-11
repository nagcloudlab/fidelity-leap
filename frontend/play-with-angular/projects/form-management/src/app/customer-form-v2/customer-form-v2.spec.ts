import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CustomerFormV2 } from './customer-form-v2';

describe('CustomerFormV2', () => {
  let component: CustomerFormV2;
  let fixture: ComponentFixture<CustomerFormV2>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CustomerFormV2]
    })
    .compileComponents();

    fixture = TestBed.createComponent(CustomerFormV2);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
