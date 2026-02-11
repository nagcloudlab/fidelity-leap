import { Component, signal } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';

@Component({
  selector: 'app-navbar',
  imports: [RouterLink, RouterLinkActive],
  templateUrl: './navbar.html',
  styleUrl: './navbar.css',
})
export class Navbar {
  isLoggedIn = signal(false);
  username = signal('');

  login(name: string) {
    this.username.set(name);
    this.isLoggedIn.set(true);
  }

  logout() {
    this.username.set('');
    this.isLoggedIn.set(false);
  }
}
