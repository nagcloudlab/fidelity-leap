import { NgClass, NgForOf, NgIf } from '@angular/common';
import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  imports: [
    NgForOf,
    NgIf,
    NgClass
  ],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = signal('shop-page-v1');
  products: Array<any> = [
    {
      id: 1,
      name: 'Laptop',
      price: 10000.0,
      description: 'A high-performance laptop for all your computing needs.',
      imageUrl: '/Laptop.png',
      isAvailable: true
    },
    {
      id: 2,
      name: 'Smartphone',
      price: 5000.0,
      description: 'A sleek smartphone with the latest features and technology.',
      imageUrl: 'Mobile.png',
      isAvailable: true
    },
  ];

  currentTabIndex: number = 1;

  addToCart(event: PointerEvent) {
    console.log('Product added to cart:');
  }

  handleTabChange(event: PointerEvent, tabIndex: number) {
    this.currentTabIndex = tabIndex; // when state is updated, Angular will automatically re-render the component to reflect the changes in the UI
  }

  isTabActive(tabIndex: number): boolean {
    return this.currentTabIndex === tabIndex;
  }

}
