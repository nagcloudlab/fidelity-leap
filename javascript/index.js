

const person = {
    name: "John",
    sayName: function () {
        console.log(this.name);
    }
}

person.sayName(); // Output: John