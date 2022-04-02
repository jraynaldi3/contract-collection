const { waffle } = require("hardhat");

const main = async()=>{
    const [signer] = await hre.ethers.getSigners()
    const contractFactory = await hre.ethers.getContractFactory("MultiSigFactory");
    const contract = await contractFactory.deploy();
    await contract.deployed()

    console.log("Deployed By: ", signer.address);
    console.log("Deployed To: ", contract.address);
    
    await hre.run("verify:verify", {
        address: contract.address,
        constructorArguments:[]
    })
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
 