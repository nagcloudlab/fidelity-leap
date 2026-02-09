import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-cart-badge',
  imports: [],
  templateUrl: './cart-badge.html',
  styleUrl: './cart-badge.css',
})
export class CartBadge {

  @Input() value: number = 0;

}
