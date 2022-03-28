const { waffle } = require("hardhat");

const main = async()=>{
    const [signer, randomPerson] = await hre.ethers.getSigners()
    const contractFactory = await hre.ethers.getContractFactory("MultiSig");
    const contract = await contractFactory.deploy([randomPerson.address], {value : hre.ethers.utils.parseEther("10") });
    await contract.deployed()
    console.log("Deployed by:" , signer.address);
    console.log("Contract Address:" , contract.address)
    const provider = await waffle.provider
    let accountBalance = hre.ethers.utils.formatEther(await provider.getBalance(randomPerson.address))
    let contractBalance = hre.ethers.utils.formatEther(await provider.getBalance(contract.address))
    console.log("Account Balance:", accountBalance)
    console.log("contract Balance:", contractBalance)
    const quorum = await contract.roleByNum[randomPerson]
    console.log ("Quorum : ",quorum)

    let tx = await contract.ethSubmitTransaction(randomPerson.address, hre.ethers.utils.parseEther("10"), 4,"");
    await tx.wait()

    contract.on("SubmitTransaction",(id,synbol,to,amount,data,endDate) =>{
        console.log("\nTransaction Submitted with id #%d", id.toNumber())
    })

    tx= await contract.approveTransaction(0);
    await tx.wait()

    contract.on("ApproveTransaction",(id,from)=>{
        console.log("\n%s has approved the transaction #%d", from, id.toNumber())
    })

    //tx= await contract.revokeApproval(0);

    tx = await contract.getApproveCount(0);
    console.log("Approved by %d person", tx.toNumber())
    
    setTimeout(async()=>await contract.executeTransaction(0), 5000)
    
    accountBalance = hre.ethers.utils.formatEther(await provider.getBalance(randomPerson.address))
    contractBalance = hre.ethers.utils.formatEther(await provider.getBalance(contract.address))
    
    console.log("contract Balance after transaction:" , contractBalance);
    console.log("Account Balance after transaction:" , accountBalance)
    
    

    contract.on("ExecuteTransaction",(id, from) =>{
        console.log("\nTransaction #%d has been executed", id)
    })
    
    //await new Promise(res => setTimeout(() => res(null), 5000));

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
 