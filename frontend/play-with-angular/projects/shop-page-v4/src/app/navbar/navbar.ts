import { Component, Input } from '@angular/core';

import { CartBadge } from '../cart-badge/cart-badge';

@Component({
  selector: 'app-navbar',
  imports: [
    CartBadge,
  ],
  templateUrl: './navbar.html',
  styleUrl: './navbar.css',
})
export class Navbar {

  @Input() title: string = 'Unknown';

}
