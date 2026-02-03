
const rxjs = require('rxjs');

const teachStream = new rxjs.Subject();

//-------------------------------------------
// trainer...
//-------------------------------------------
let i = 0;
setInterval(() => {
    i++;
    console.log(`\nTrainer: Teaching/publishing Topic ${i}`);
    teachStream.next(`Topic ${i}`);
}, 2000);


//-------------------------------------------
// employee-1
//-------------------------------------------

teachStream.subscribe({
    next: (topic) => {
        console.log(`Employee-1: Received notification for ${topic}. Going to learn it now...`);
    },
    error: (err) => {
        console.error('Employee-1: Error occurred:', err);
    },
    complete: () => {
        console.log('Employee-1: Training completed.');
    }
});



//-------------------------------------------
// employee-2
//-------------------------------------------

teachStream.subscribe({
    next: (topic) => {
        console.log(`Employee-2: Received notification for ${topic}. Going to learn it now...`);
    },
    error: (err) => {
        console.error('Employee-2: Error occurred:', err);
    },
    complete: () => {
        console.log('Employee-2: Training completed.');
    }
});