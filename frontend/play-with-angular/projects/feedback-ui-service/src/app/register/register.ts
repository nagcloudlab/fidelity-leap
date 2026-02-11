import { Component, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-register',
  imports: [FormsModule, RouterLink],
  templateUrl: './register.html',
  styleUrl: './register.css',
})
export class Register {
  username = '';
  email = '';
  password = '';
  confirmPassword = '';
  errorMessage = signal('');
  successMessage = signal('');

  onSubmit() {
    this.errorMessage.set('');
    this.successMessage.set('');

    if (!this.username || !this.email || !this.password || !this.confirmPassword) {
      this.errorMessage.set('Please fill in all fields.');
      return;
    }
    if (this.password !== this.confirmPassword) {
      this.errorMessage.set('Passwords do not match.');
      return;
    }

    // Static demo
    this.successMessage.set('Account created! You can now log in.');
    this.username = '';
    this.email = '';
    this.password = '';
    this.confirmPassword = '';
  }
}
