import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Pour rootBundle
import 'dart:convert'; // Pour jsonDecode
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:web_socket_channel/io.dart';

class ContractLinking extends ChangeNotifier {
  // 1. Variables de configuration
  final String _rpcUrl = "http://127.0.0.1:7545";
  final String _wsUrl = "ws://127.0.0.1:7545/";
  final String _privateKey =
      "0x320c95aa1d064dffc0eaf3c0845feeaf4e37f0075f6b7a5a277816bd81343380";

  // 2. Variables d'état (TOUTES doivent être DANS la classe)
  late Web3Client _client;
  bool isLoading = true;

  late String _abiCode;
  late EthereumAddress _contractAddress;
  late Credentials _credentials;
  late DeployedContract _contract;
  late ContractFunction _yourName;
  late ContractFunction _setName;

  String deployedName = ""; // Initialisation vide pour éviter les erreurs null

  // 3. Constructeur
  ContractLinking() {
    initialSetup();
  }

  // 4. Initialisation
  initialSetup() async {
    // establish a connection to the ethereum rpc node.
    _client = Web3Client(
      _rpcUrl,
      Client(),
      socketConnector: () {
        return IOWebSocketChannel.connect(_wsUrl).cast<String>();
      },
    );
    await getAbi();
    await getCredentials();
    await getDeployedContract();
  }

  Future<void> getAbi() async {
    // Reading the contract abi
    String abiStringFile = await rootBundle.loadString(
      "src/artifacts/HelloWorld.json",
    );
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _contractAddress = EthereumAddress.fromHex(
      jsonAbi["networks"]["5777"]["address"],
    );
  }

  Future<void> getCredentials() async {
    _credentials = await _client.credentialsFromPrivateKey(_privateKey);
  }

  Future<void> getDeployedContract() async {
    // Telling Web3dart where our contract is declared.
    _contract = DeployedContract(
      ContractAbi.fromJson(_abiCode, "HelloWorld"),
      _contractAddress,
    );
    // Extracting the functions, declared in contract.
    _yourName = _contract.function("yourName");
    _setName = _contract.function("setName");
    getName();
  }

  getName() async {
    // Getting the current name declared in the smart contract.
    var currentName = await _client.call(
      contract: _contract,
      function: _yourName,
      params: [],
    );
    deployedName = currentName[0];
    isLoading = false;
    notifyListeners();
  }

  setName(String nameToSet) async {
    // 1. Activer le chargement
    isLoading = true;
    notifyListeners();

    // 2. Envoyer la transaction avec des paramètres explicites
    try {
      await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: _setName,
          parameters: [nameToSet],
          // FIX 1 : On force une limite de gaz élevée pour éviter les erreurs d'estimation
          maxGas: 6721975,
        ),
        // FIX 2 : On force l'ID du réseau (Chain ID) de Ganache.
        // Essayez 1337 (standard Ganache) ou 5777 (votre configuration TP)
        chainId: 1337,
      );

      // Petite pause pour laisser le temps à Ganache d'écrire le bloc
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      print("Erreur lors de la transaction : $e");
      // Optionnel : Afficher l'erreur dans la console du navigateur
    }

    // 3. Mettre à jour l'affichage
    getName();
  }
} // <--- La classe se ferme UNIQUEMENT ICI, à la toute fin du fichier
