# OptiRoute

## 1. Título do projeto
OptiRoute

## 2. Descrição clara e curta do que o projeto faz
OptiRoute é uma biblioteca/utilitário para processamento e optimização de percursos com dados de localização. Inclui ferramentas para:
- limpeza e preparação de trilhos GPS (remoção de outliers e duplicados por proximidade)
- cálculo de distâncias, tempos estimados de viagem e estatísticas
- operações geométricas em coordenadas (bearing, interpolações, centroides, midpoints, clusters)
- integração com MapKit (polylines, anotações, snapshots, pesquisa de pontos próximos numa rota)
- geocodificação inversa para nomes de localidades e identificação de fusos horários

## 3. Requisitos
- Sistemas operativos suportados:
  - iOS 17 ou superior
  - macOS 13 (Ventura) ou superior
- Xcode 16 ou superior
- Swift 6.0 ou superior
- Frameworks: MapKit, CoreLocation (opcionalmente HealthKit, se aplicável)

Nota: Alguns métodos tiram partido de APIs recentes do MapKit; ajuste a versão mínima caso use funcionalidades não disponíveis em versões anteriores.

## 4. Instalação
Recomendado: Swift Package Manager (SPM)

- No Xcode: File → Add Packages… → introduza o URL do repositório e escolha a versão.
- Ou adicione manualmente ao `Package.swift` do seu projeto:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
        .iOS(.v17), .macOS(.v13)
    ],
    dependencies: [
        // Substitua pelo URL real do repositório
        .package(url: "https://github.com/SEU-UTILIZADOR/OptiRoute.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: ["OptiRoute"]
        )
    ]
)
