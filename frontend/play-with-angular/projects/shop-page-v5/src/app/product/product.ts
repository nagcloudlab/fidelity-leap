import { CurrencyPipe, DatePipe, JsonPipe, NgClass, NgFor, NgIf, UpperCasePipe } from '@angular/common';
import { Component, EventEmitter, Input, Output, ViewChild } from '@angular/core';
import { Review } from '../review/review';
import { Highlight } from '../highlight';
import { DiscountPipe } from '../discount-pipe';
import { CartService } from '../cart-service';
import { ProductServicce } from '../product-servicce';

@Component({
  selector: 'app-product',
  imports: [
    NgClass,
    NgIf,
    NgFor,
    Review,
    Highlight,
    CurrencyPipe,
    DatePipe,
    UpperCasePipe,
    JsonPipe,
    DiscountPipe
  ],
  templateUrl: './product.html',
  styleUrl: './product.css',
  // providers: [CartService] // provide the CartService at the component level, so each instance of Product will have its own instance of CartService
})
export class Product {

  @Input() product: any;

  // DI
  constructor(private cartService: CartService, private productService: ProductServicce) { }


  // @ViewChild('productItem') productItemDiv: any;

  currentTabIndex: number = 1;

  reviews: Array<any> = []

  addToCart(event: PointerEvent) {
    this.cartService.addToCart(this.product);
  }

  handleTabChange(event: PointerEvent, tabIndex: number) {
    event.preventDefault(); // prevent the default behavior of the anchor tag, which is to navigate to a new page
    this.currentTabIndex = tabIndex; // when state is updated, Angular will automatically re-render the component to reflect the changes in the UI
    if (tabIndex === 3) {
      this.productService.getReviews(this.product.id).subscribe((reviews: any) => {
        this.reviews = reviews;
      });
    }
  }

  isTabActive(tabIndex: number): boolean {
    return this.currentTabIndex === tabIndex;
  }


  // ngAfterViewInit() {
  // console.log(this.productItemDiv);
  // this.productItemDiv.nativeElement.addEventListener('mouseenter', (event: PointerEvent) => {
  //   this.productItemDiv.nativeElement.style.backgroundColor = 'yellow';
  // });
  // this.productItemDiv.nativeElement.addEventListener('mouseleave', (event: PointerEvent) => {
  //   this.productItemDiv.nativeElement.style.backgroundColor = 'white';
  // });
  // }

}
