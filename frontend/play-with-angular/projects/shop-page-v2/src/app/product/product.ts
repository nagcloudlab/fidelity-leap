import { NgClass, NgFor, NgIf } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { Review } from '../review/review';

@Component({
  selector: 'app-product',
  imports: [
    NgClass,
    NgIf,
    NgFor,
    Review
  ],
  templateUrl: './product.html',
  styleUrl: './product.css',
})
export class Product {

  @Input() product: any;
  @Output() buy: EventEmitter<any> = new EventEmitter();

  currentTabIndex: number = 1;

  reviews: Array<any> = [
    {
      stars: 5,
      body: 'I love this product!',
      author: 'who1'
    },
    {
      stars: 4,
      body: 'This product is pretty good.',
      author: 'who2'
    }
  ]

  addToCart(event: PointerEvent) {
    this.buy.emit(this.product);
  }

  handleTabChange(event: PointerEvent, tabIndex: number) {
    this.currentTabIndex = tabIndex; // when state is updated, Angular will automatically re-render the component to reflect the changes in the UI
  }

  isTabActive(tabIndex: number): boolean {
    return this.currentTabIndex === tabIndex;
  }

}
