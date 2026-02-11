import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CustomerFormV1 } from './customer-form-v1';

describe('CustomerFormV1', () => {
  let component: CustomerFormV1;
  let fixture: ComponentFixture<CustomerFormV1>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CustomerFormV1]
    })
    .compileComponents();

    fixture = TestBed.createComponent(CustomerFormV1);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
