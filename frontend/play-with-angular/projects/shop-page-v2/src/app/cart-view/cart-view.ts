import { DatePipe, NgFor, NgIf } from '@angular/common';
import { Component, ContentChild, Input, signal, SimpleChange, ViewChild } from '@angular/core';

@Component({
  selector: 'app-cart-view',
  imports: [
    NgIf,
    NgFor,
    DatePipe
  ],
  templateUrl: './cart-view.html',
  styleUrl: './cart-view.css',
})
export class CartView {

  @Input() cart: Array<any> = [];
  counter = signal(0);
  counterIntervalId: any;

  @ContentChild('cf') contentFooter: any;
  @ViewChild('vf') viewFooter: any;

  constructor() {
    console.log('CartView::constructor');
    // why we need?
    // - to do dependency injection
  }


  ngOnChanges(change: SimpleChange) {
    console.log('CartView::ngOnChanges');
    // why we need?
    // - to react to changes in input properties
    console.log(change);
  }


  ngOnInit() {
    console.log('CartView::ngOnInit');
    // why we need?
    // - to do initialization work after the component is created
    // - to fetch data from server
    this.counterIntervalId = setInterval(() => {
      this.counter.update(v => v + 1);
    }, 1000);
  }


  ngOnDestroy() {
    console.log('CartView::ngOnDestroy');
    // why we need?
    // - to do cleanup work before the component is destroyed
    // - to cancel timers, unsubscribe from observables, etc.
    clearInterval(this.counterIntervalId);
  }

  ngAfterContentInit() {
    console.log('CartView::ngAfterContentInit');
    // why we need?
    // - to do work after the component's view has been fully initialized
    // - to access child components, DOM elements, etc.
    // if footer content is not projected into this component, then keep default value
    console.log(this.contentFooter);
  }

  ngAfterViewInit() {
    console.log('CartView::ngAfterViewInit');
    // why we need?
    // - to do work after the component's view has been fully initialized
    // - to access child components, DOM elements, etc.
    if (!this.contentFooter) {
      this.viewFooter.nativeElement.innerHTML = 'this default footer to the cart view';
    }
  }

}



