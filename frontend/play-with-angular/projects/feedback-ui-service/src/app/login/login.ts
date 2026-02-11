import { Component, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-login',
  imports: [FormsModule, RouterLink],
  templateUrl: './login.html',
  styleUrl: './login.css',
})
export class Login {
  username = '';
  password = '';
  errorMessage = signal('');
  successMessage = signal('');

  onSubmit() {
    this.errorMessage.set('');
    this.successMessage.set('');

    if (!this.username || !this.password) {
      this.errorMessage.set('Please fill in all fields.');
      return;
    }

    // Static demo — simulate login
    this.successMessage.set(`Welcome back, ${this.username}! Redirecting...`);
  }
}
