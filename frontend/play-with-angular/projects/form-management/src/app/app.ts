import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { CustomerFormV1 } from './customer-form-v1/customer-form-v1';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, CustomerFormV1],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = signal('form-management');
}
