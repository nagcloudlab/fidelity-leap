
function teach(sub) {
    console.log(`teaching ${sub}`);
    let notes = `${sub}-notes`;
    function learn() {
        console.log("learning starts");
        console.log("learning with " + notes);
    }
    console.log(`teaching ends`);
    return learn;
}

let learnFunc = teach("JS");
learnFunc();

// function closure
//--------------------

// A closure is a function that retains access to its lexical scope 
// even when the function is executed outside that scope.

// why use closures?
// data privacy


// counter module


function init() {
    let count = 10; // private variable
    function increment() {
        count++;
    }
    function getCount() {
        return count;
    }
    return {
        increment: increment,
        getCount: getCount
    }
}
let counter = init();