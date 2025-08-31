#!/bin/bash
set -e

echo "Setting up Hyperledger Fabric network..."

FABRIC_ROOT="/home/michal/NanoTrace/fabric-network"
mkdir -p $FABRIC_ROOT
cd $FABRIC_ROOT

# Download Fabric binaries and samples
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.4 1.5.7

# Create network configuration
mkdir -p network/organizations/{peerOrganizations,ordererOrganizations}
mkdir -p network/configtx
mkdir -p network/docker
mkdir -p network/scripts

# Create docker-compose for test network
cat > network/docker/docker-compose-test-net.yaml << 'DOCKER_COMPOSE'
version: '3.7'

volumes:
  orderer.nanotrace.org:
  peer0.org1.nanotrace.org:
  peer0.org2.nanotrace.org:

networks:
  nanotrace:
    name: fabric_nanotrace

services:
  orderer.nanotrace.org:
    container_name: orderer.nanotrace.org
    image: hyperledger/fabric-orderer:2.5.4
    environment:
      - FABRIC_LOGGING_SPEC=INFO
      - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
      - ORDERER_GENERAL_LISTENPORT=7050
      - ORDERER_GENERAL_LOCALMSPID=OrdererMSP
      - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp
      - ORDERER_GENERAL_TLS_ENABLED=true
      - ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
      - ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
      - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric
    command: orderer
    volumes:
      - ../organizations/ordererOrganizations/nanotrace.org/orderers/orderer.nanotrace.org/msp:/var/hyperledger/orderer/msp
      - ../organizations/ordererOrganizations/nanotrace.org/orderers/orderer.nanotrace.org/tls/:/var/hyperledger/orderer/tls
      - orderer.nanotrace.org:/var/hyperledger/production/orderer
    ports:
      - 7050:7050
      - 7053:7053
    networks:
      - nanotrace

  peer0.org1.nanotrace.org:
    container_name: peer0.org1.nanotrace.org
    image: hyperledger/fabric-peer:2.5.4
    environment:
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=fabric_nanotrace
      - FABRIC_LOGGING_SPEC=INFO
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_PROFILE_ENABLED=false
      - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
      - CORE_PEER_ID=peer0.org1.nanotrace.org
      - CORE_PEER_ADDRESS=peer0.org1.nanotrace.org:7051
      - CORE_PEER_LISTENADDRESS=0.0.0.0:7051
      - CORE_PEER_CHAINCODEADDRESS=peer0.org1.nanotrace.org:7052
      - CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:7052
      - CORE_PEER_GOSSIP_BOOTSTRAP=peer0.org1.nanotrace.org:7051
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org1.nanotrace.org:7051
      - CORE_PEER_LOCALMSPID=Org1MSP
      - CORE_OPERATIONS_LISTENADDRESS=peer0.org1.nanotrace.org:9444
    volumes:
      - /var/run/docker.sock:/host/var/run/docker.sock
      - ../organizations/peerOrganizations/org1.nanotrace.org/peers/peer0.org1.nanotrace.org/msp:/etc/hyperledger/fabric/msp
      - ../organizations/peerOrganizations/org1.nanotrace.org/peers/peer0.org1.nanotrace.org/tls:/etc/hyperledger/fabric/tls
      - peer0.org1.nanotrace.org:/var/hyperledger/production
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    command: peer node start
    ports:
      - 7051:7051
      - 9444:9444
    networks:
      - nanotrace

  cli:
    container_name: cli
    image: hyperledger/fabric-tools:2.5.4
    environment:
      - GOPATH=/opt/gopath
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - FABRIC_LOGGING_SPEC=INFO
      - CORE_PEER_ID=cli
      - CORE_PEER_ADDRESS=peer0.org1.nanotrace.org:7051
      - CORE_PEER_LOCALMSPID=Org1MSP
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.nanotrace.org/peers/peer0.org1.nanotrace.org/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.nanotrace.org/peers/peer0.org1.nanotrace.org/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.nanotrace.org/peers/peer0.org1.nanotrace.org/tls/ca.crt
      - CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.nanotrace.org/users/Admin@org1.nanotrace.org/msp
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    command: /bin/bash
    volumes:
      - /var/run/docker.sock:/host/var/run/docker.sock
      - ../organizations:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/
      - ../../chaincode:/opt/gopath/src/github.com/chaincode
    depends_on:
      - peer0.org1.nanotrace.org
    networks:
      - nanotrace
DOCKER_COMPOSE
