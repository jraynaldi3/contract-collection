const main = async()=>{
    const contractFactory = await hre.ethers.getContractFactory("MultiSig");
    const contract = await contractFactory.deploy([]);
    await contract.deployed()

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
 