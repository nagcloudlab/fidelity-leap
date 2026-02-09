import { ComponentFixture, TestBed } from '@angular/core/testing';

import { VotingBox } from './voting-box';

describe('VotingBox', () => {
  let component: VotingBox;
  let fixture: ComponentFixture<VotingBox>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [VotingBox]
    })
    .compileComponents();

    fixture = TestBed.createComponent(VotingBox);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
