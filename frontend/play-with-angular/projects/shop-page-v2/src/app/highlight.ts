import { Directive, ElementRef, HostListener, Input } from '@angular/core';

@Directive({
  selector: '[appHighlight]',
})
export class Highlight {

  @Input() appHighlight: string = 'yellow';

  ele: ElementRef;

  constructor(ele: ElementRef) {
    console.log('Highlight directive created');
    this.ele = ele;
  }

  // ngOnInit() {
  //   this.ele.nativeElement.addEventListener('mouseenter', (event: PointerEvent) => {
  //     this.ele.nativeElement.style.backgroundColor = this.appHighlight;
  //   });
  //   this.ele.nativeElement.addEventListener('mouseleave', (event: PointerEvent) => {
  //     this.ele.nativeElement.style.backgroundColor = 'white';
  //   });
  // }

  @HostListener('mouseenter')
  onMouseEnter() {
    this.ele.nativeElement.style.backgroundColor = this.appHighlight;
  }

  @HostListener('mouseleave')
  onMouseLeave() {
    this.ele.nativeElement.style.backgroundColor = 'white';
  }


}
