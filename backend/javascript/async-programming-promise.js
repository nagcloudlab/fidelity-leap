


//-------------------------------------------
// trainer...
//-------------------------------------------

const trainer = {
    getTopicDetails(topic) {
        const promise = new Promise((resolve, reject) => {
            setTimeout(() => {
                const details = `Details about ${topic}`;
                console.log("trainer resolving promise with topic details...");
                resolve(details); // pushing data to promise

                //console.log("trainer rejecting promise with error...");
                //reject("Failed to get topic details"); // pushing error to promise

            }, 2000);
        });
        return promise;
    }
}


//-------------------------------------------
// LLM model
//-------------------------------------------

const llmModel = {
    generateResponse(prompt) {
        return new Promise((resolve) => {
            setTimeout(() => {
                console.log("LLM model generating response...");
                const response = `Response to "${prompt}"`;
                resolve(response);
            }, 1500);
        });
    }
};



//-------------------------------------------
// employee
//-------------------------------------------

const employee = {
    async doLearn() {
        console.log("Employee is learning...");
        let topic = "topic1"
        try {
            const details = await trainer.getTopicDetails(topic);
            console.log("Employee received topic details:", details);
            const llmResponse = await llmModel.generateResponse(details);
            console.log("Employee received LLM response:", llmResponse);
        } catch (error) {
            console.error("Error during learning process:", error);
        }
    },
    doWork() {
        this.doLearn()
        console.log("Employee is working...");
    }
};

//-------------------------------------------
// simulate...
//-------------------------------------------

employee.doWork();