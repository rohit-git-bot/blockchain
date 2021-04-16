const express = require("express");
const multer = require("multer");
const path = require("path");
var BigNumber = require('big-number');
const Web3 = require('web3')
const fs = require('fs')
var Tx = require('ethereumjs-tx').Transaction
const web3 = new Web3('https://ropsten.infura.io/v3/2b4811e72fea40febaf0978bee0d2aac') // Your Infura Endpoint here 

const app = express();
const port = 3000;

const storage = multer.memoryStorage();


let style = '<style>  table {    font-family: arial, sans-serif;    border-collapse: collapse;    width: 100px;  }    td, th {    border: 1px solid #dddddd;    text-align: left;    padding: 8px;  }    tr:nth-child(even) {    background-color: #dddddd;  }  </style>';
let htmlopMain = '<caption style="caption-side:center">Information</caption><table style="width:100%">';
let htmlop = '<caption style="caption-side:center">Transaction</caption><table style="width:100%">';
const fileFilter = (req, file, cb) => {
    if (file.mimetype == 'text/plain') { // checking the MIME type of the uploaded file
        cb(null, true);
    } else {
        cb(null, false);
    }
}

const upload = multer({
    fileFilter,
    storage
});

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname + "/index.html"));
});

app.post("/uploadFile", upload.single("myFile"), (req, res, next) => { 
  const file = req.file;

  if (!file) {
    const error = new Error("Please upload a file");
    error.httpStatusCode = 400;
    return next(error);
  }
  const multerText = Buffer.from(file.buffer).toString("utf-8");
  
  const result = {
    fileText: multerText,
  };  
  var os = require("os");
  let totalEtherAddr = multerText.split(/[\r\n]+/).length
  
  res.setHeader("Content-Type", "text/html");
  //res.write("<p>Transaction Begin</p>");
  
  
  let promise = new Promise(function(resolve, reject) {
  getcalc(Number(totalEtherAddr)).then(value => {
    const forLoop = async() => {
      for(let val of multerText.split(/[\r\n]+/)) {
        if(val){
          console.log("\n\n")
          console.log("Ether address = "+val)
          htmlop += '<tr><td>Ether address </td><td>'+val+'</td></tr>'
          await go(val,value)
        }

      }
      htmlop += '</table>'
      htmlopMain += '</table><br><br><br>'
      return res.send(style+ htmlopMain+htmlop);   
    }
    
    forLoop()

    
   // res.write(htmlop.concat('</html>'));
    
  });
});

promise.then((res) => {
  return res.send("Success")
}).catch((error) => {
  return res.send("Failure")
})

  

  //res.end()
  
  
});




app.listen(port, () => console.log(`App listening on port ${port}!`));


/**************************************************************************************************/

const mainAccnt = '0x0822FC942B09AA5874C31df95820ADd8B16484Da' // Your mainAccnt address 1


// put in your private keys here (from metamask) for main account
const privateKey1 = Buffer.from('ab56faae90b595c03f1b278bbd69ee4393023428790130e0435594fb9f5a5a39', 'hex')



// Read the deployed contract - get the addresss from Etherscan 
// - use your deployed contract address here!
const contractAddress = '0x6431951889b319d731520b1c874b569f09a87593'


// Reading ABI file from ABI.json
var jsonABI = fs.readFileSync("ABI.json")
const contractABI = JSON.parse(jsonABI)

// Getting contract with help of ABI and contract address
const contract = new web3.eth.Contract(contractABI, contractAddress)


const getTransactionCount = async(account) => {
  return await web3.eth.getTransactionCount(account)
}

const sendTransaction = async(raw) => {
  return await web3.eth.sendSignedTransaction(raw)
}

const transferFunds = async(account1, account2, amount) => {

  let txCount = await getTransactionCount(account1)

  console.log("Txn Count returned: " + txCount)

  //const accountNonce = '0x' + (web3.eth.getTransactionCount(account1) + 1).toString(16)

  const txObject = {
    nonce: web3.utils.toHex(txCount),
    gasLimit: web3.utils.toHex(100000), // uses about 36,000 gas so add some buffer
    gasPrice: web3.utils.toHex(web3.utils.toWei('30', 'gwei')),
    to: contractAddress,
    data: contract.methods.transfer(account2, amount).encodeABI()
  }

  const tx = new Tx(txObject, {chain:'ropsten', hardfork: 'petersburg'})

  tx.sign(privateKey1)

  const serializedTx = tx.serialize()
  const raw = '0x' + serializedTx.toString('hex')

  // console.log("raw hex transaction: " + raw)

  console.log("sending transaction....")

  let minedTransaction = await sendTransaction(raw)
  console.log("Transaction hash returned: " + minedTransaction.transactionHash)

  return `txHash is: ${minedTransaction.transactionHash}`
}

// async methods
const getBalanceOf = async(account) => {
  let balanceOf = await contract.methods.balanceOf(account).call()
  return `balance of account ${account} is ${balanceOf}`
}

const getBalanceOfAcc = async(account) => {
  let balanceOf = await contract.methods.balanceOf(account).call()
  return balanceOf
}

const go = async(destn, tokenamt) => {

  try{    
     
    console.log("Token Amount: "+tokenamt)
    await transferFunds(mainAccnt, destn, tokenamt)
    console.log("Total Balance for (Main Account) " + mainAccnt + " : "+await getBalanceOfAcc(mainAccnt))
    console.log("Total Balance for " + destn + " : "+await getBalanceOfAcc(destn))
    htmlop += '<tr><td>Total Balance for (Main Account) - ' + mainAccnt + ' </td> <td>'+await getBalanceOfAcc(mainAccnt) +'</td></tr>'
    htmlop += '<tr><td>Total Balance for ' + destn + ' </td> <td>'+await getBalanceOfAcc(destn)+'</td></tr>'
  }catch (err){
    return console.log(err)
  }
}


// Calculates the 5 percent of total token counts and 
// also divides tokens equally among totalEtherAddr count from uploaded file
const getcalc = async(totalEtherAddr) =>{

  const totBalance = await getBalanceOfAcc(mainAccnt)
  console.log("\nTotal Balance for " + mainAccnt + ": " + totBalance)
  htmlopMain += '<tr><td>Total Balance for (main account):'+mainAccnt+'</td><td>'+totBalance+'</td></tr>'
  const totTokenCnt = new BigNumber(totBalance).div(20)
  //totTokenCnt = 
  console.log("5% Token Amount: " + totTokenCnt)
  console.log("totalEtherAddr: " + totalEtherAddr)
  htmlopMain += '<tr><td>5% Token Amount:</td><td>'+totTokenCnt+'</td></tr>'
  htmlopMain += '<tr><td>Total Ethereum Accounts</td><td>'+totalEtherAddr+'</td></tr>'
  let singleTokenCnt = totTokenCnt.div(totalEtherAddr)
  console.log("Single Token count: " + singleTokenCnt)
  htmlopMain += '<tr><td>Token Amount to be transferred (per account)</td><td>'+singleTokenCnt+'</td></tr>'
  return singleTokenCnt
}

module.exports = { transferFunds, getBalanceOf }

