import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'discount',
})
export class DiscountPipe implements PipeTransform {

  transform(value: number, ...args: number[]): number {
    const discountPercentage = args[0] || 0; // default to 0% discount if not provided
    const discountAmount = (value * discountPercentage) / 100;
    return value - discountAmount;
  }

}
