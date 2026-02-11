import { JsonPipe, NgIf } from '@angular/common';
import { Component } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';

import { debounceTime, map } from 'rxjs/operators';

@Component({
  selector: 'app-customer-form-v2',
  imports: [
    ReactiveFormsModule,
    JsonPipe,
    NgIf
  ],
  templateUrl: './customer-form-v2.html',
  styleUrl: './customer-form-v2.css',
})
export class CustomerFormV2 {

  customerForm!: FormGroup
  submitted: boolean = false

  constructor(private fb: FormBuilder) { }


  handleSubmit() {
    this.submitted = true
    if (this.customerForm.valid) {
      console.log('Form value: ', this.customerForm.value);
    }
  }

  ngOnInit() {

    this.customerForm = this.fb.group({
      firstName: ['Nag', [Validators.required, Validators.minLength(3)]],
      lastName: ['Nag', [Validators.required, Validators.minLength(3)]],
      emailGroup: this.fb.group({
        email: ['nag@example.com', [Validators.required, Validators.email]],
        confirmEmail: ['nag@example.com', [Validators.required, Validators.email]]
      }, { validators: this.emailMatchValidator }),
      compnay: ['Fidelity', Validators.required, this.customValidator],
      notification: ['email'],
      phone: ['']
    })

    // this.customerForm.statusChanges.subscribe(status => {
    //   console.log('Form status: ', status);
    // })
    // this.customerForm.valueChanges.subscribe(value => {
    //   console.log('Form value: ', value);
    // })

    // this.customerForm.get('firstName')?.statusChanges.subscribe(status => {
    //   console.log('First name status: ', status);
    // });
    // this.customerForm.get('firstName')?.valueChanges.subscribe(value => {
    //   console.log('First name value: ', value);
    // });

    // this.customerForm.get('firstName')?.statusChanges
    //   .pipe(debounceTime(5000))
    //   .subscribe(status => {
    //     console.log('First name status: ', status);
    //   });


    this.customerForm.get('notification')?.valueChanges.subscribe(value => {
      const phoneControl = this.customerForm.get('phone')
      if (value === 'text') {
        phoneControl?.setValidators(Validators.required)
      } else {
        phoneControl?.clearValidators()
      }
      phoneControl?.updateValueAndValidity()
    })


  }

  emailMatchValidator(group: FormGroup) {
    const email = group.get('email')?.value
    const confirmEmail = group.get('confirmEmail')?.value

    return email === confirmEmail ? null : { emailMismatch: true }
  }

  customValidator(control: any) {
    return new Promise(resolve => {
      setTimeout(() => {
        if (control.value === 'Fidelity') {
          resolve(null)
        } else {
          resolve({ companyInvalid: true })
        }
      }, 1000)
    })
  }

}
