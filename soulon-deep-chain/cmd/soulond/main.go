package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"

	"soulon-deep-chain/app"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: soulond <validate-genesis|demo>")
		os.Exit(2)
	}
	switch os.Args[1] {
	case "validate-genesis":
		if err := runValidateGenesis(os.Args[2:]); err != nil {
			fmt.Fprintln(os.Stderr, err.Error())
			os.Exit(1)
		}
	case "demo":
		if err := runDemo(os.Args[2:]); err != nil {
			fmt.Fprintln(os.Stderr, err.Error())
			os.Exit(1)
		}
	default:
		fmt.Fprintln(os.Stderr, "unknown command")
		os.Exit(2)
	}
}

func runValidateGenesis(args []string) error {
	command := flag.NewFlagSet("validate-genesis", flag.ContinueOnError)
	command.SetOutput(os.Stderr)
	genesisFile := command.String("file", "config/genesis.template.json", "genesis file path")
	if err := command.Parse(args); err != nil {
		return err
	}
	chainApp := app.NewChainApp()
	if err := chainApp.ValidateGenesis(*genesisFile); err != nil {
		return err
	}
	fmt.Println("genesis validation passed")
	return nil
}

func runDemo(args []string) error {
	command := flag.NewFlagSet("demo", flag.ContinueOnError)
	command.SetOutput(os.Stderr)
	genesisFile := command.String("file", "config/genesis.template.json", "genesis file path")
	responseVersion := command.String("response-version", app.TxResponseVersionLatest, "response protocol version")
	if err := command.Parse(args); err != nil {
		return err
	}
	if err := app.ValidateTxResponseVersion(*responseVersion); err != nil {
		return err
	}
	chainApp := app.NewChainApp()
	genesis, err := app.LoadGenesisFromFile(*genesisFile)
	if err != nil {
		return err
	}
	if err := chainApp.InitFromGenesis(genesis); err != nil {
		return err
	}
	bankResponse := chainApp.ExecuteTxResponseWithVersion(*responseVersion, app.Tx{
		Type:   app.TxBankSend,
		From:   "alice",
		To:     "bob",
		Amount: 1,
	})
	printTxResponse("bank_send", bankResponse)
	if bankResponse.Code != "OK" {
		fmt.Println("bank demo skipped")
	}
	delegateResponse := chainApp.ExecuteTxResponseWithVersion(*responseVersion, app.Tx{
		Type:      app.TxStakingDelegate,
		Delegator: "alice",
		Validator: "validator-1",
		Amount:    10,
	})
	printTxResponse("staking_delegate", delegateResponse)
	if delegateResponse.Code != "OK" {
		return fmt.Errorf("staking delegate failed")
	}
	submitResponse := chainApp.ExecuteTxResponseWithVersion(*responseVersion, app.Tx{
		Type:  app.TxGovSubmit,
		From:  "alice",
		Title: "enable ibc transfer",
	})
	printTxResponse("gov_submit", submitResponse)
	submitData, ok := submitResponse.Data.(app.GovSubmitData)
	if submitResponse.Code != "OK" || !ok {
		return fmt.Errorf("gov submit failed")
	}
	voteResponse := chainApp.ExecuteTxResponseWithVersion(*responseVersion, app.Tx{
		Type:       app.TxGovVote,
		ProposalID: submitData.ProposalID,
		Option:     "yes",
		Amount:     10,
	})
	printTxResponse("gov_vote", voteResponse)
	if voteResponse.Code != "OK" {
		return fmt.Errorf("gov vote failed")
	}
	tallyResponse := chainApp.ExecuteTxResponseWithVersion(*responseVersion, app.Tx{
		Type:        app.TxGovTally,
		ProposalID:  submitData.ProposalID,
		VotingPower: 20,
	})
	printTxResponse("gov_tally", tallyResponse)
	tallyData, ok := tallyResponse.Data.(app.GovTallyData)
	if tallyResponse.Code != "OK" || !ok {
		return fmt.Errorf("gov tally failed")
	}
	fmt.Printf("demo completed: proposal=%d accepted=%t quorum=%t\n", submitData.ProposalID, tallyData.Accepted, tallyData.QuorumMet)
	return nil
}

func printTxResponse(step string, response app.TxResponse) {
	payload, err := json.Marshal(response)
	if err != nil {
		fmt.Printf("%s: marshal response failed\n", step)
		return
	}
	fmt.Printf("%s: %s\n", step, string(payload))
}
