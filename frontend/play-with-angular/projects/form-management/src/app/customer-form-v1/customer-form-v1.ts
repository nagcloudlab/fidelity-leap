import { JsonPipe, NgIf } from '@angular/common';
import { Component } from '@angular/core';
import { FormGroup, FormsModule, NgForm } from '@angular/forms';

@Component({
  selector: 'app-customer-form-v1',
  imports: [
    FormsModule,
    JsonPipe,
    NgIf
  ],
  templateUrl: './customer-form-v1.html',
  styleUrl: './customer-form-v1.css',
})
export class CustomerFormV1 {


  customerModel = {
    firstName: '',
    lastName: '',
  };

  handleSubmit(event: SubmitEvent, customerForm: NgForm) {
    event.preventDefault();
    console.log(customerForm.value);
    console.log(this.customerModel);
  }

  loadCustomer() {
    // api call to load customer data
    const customer = {
      firstName: 'John',
      lastName: 'Doe',
    }
    this.customerModel = customer;
  }
}
