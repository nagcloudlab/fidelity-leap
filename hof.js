
// HOF => Higher Order Function


function hello() {
    console.log("hello")
}

function hi() {
    console.log("hi")
}
function hey() {
    console.log("hey")
}


/*

design issues
--------------
-> code coupling/tangling
-> code duplication/redundancy/scattering

*/

function withEmoji(fn) {
    return function () {
        fn()
        console.log("😀")
    }
}



hello();
let hello_with_emoji = withEmoji(hello)
hello_with_emoji();

hi();
let hi_with_emoji = withEmoji(hi)
hi_with_emoji();

hey();
let hey_with_emoji = withEmoji(hey)
hey_with_emoji();


// when function is first class citizen
//-------------------------------------
// functions can be passed as arguments to other functions
// functions can be returned from other functions
// functions can be assigned to variables
