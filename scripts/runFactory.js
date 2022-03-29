const { waffle } = require("hardhat");

const main = async()=>{
    const [signer, randomPerson] = await hre.ethers.getSigners()
    const contractFactory = await hre.ethers.getContractFactory("MultiSigFactory");
    const contract = await contractFactory.deploy();
    await contract.deployed()

    console.log("Deployed By: ", signer.address);
    console.log("Deployed To: ", contract.address);
   
    let tx = await contract.createWallet("mama", [randomPerson.address])
    await tx.wait();
    
}

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error){
        console.error(error);
        process.exit(1);
    }
}

runMain();
 