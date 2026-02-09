import { ComponentFixture, TestBed } from '@angular/core/testing';

import { VotingItem } from './voting-item';

describe('VotingItem', () => {
  let component: VotingItem;
  let fixture: ComponentFixture<VotingItem>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [VotingItem]
    })
    .compileComponents();

    fixture = TestBed.createComponent(VotingItem);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
