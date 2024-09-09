## ISTIO 0.21.4 Installation

https://istio.io/latest/docs/setup/getting-started/
```
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.23.0
export PATH=$PWD/bin:$PATH
```

|Name | default | demo | minimal |remote | empty | preview | ambient|
|-|-|-|-|-|-|-|-|
|Core components | | | | | | |
|istio-egressgateway| |✔| | | | | |
|istio-ingressgateway|✔|✔||||✔||
|istiod|✔	|✔	|✔| | |✔|✔|
|CNI| | | | | |	|✔|
|Ztunnel| | | | | ||✔|
      
```
istioctl install --set profile=demo
```

## 
