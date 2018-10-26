//
//  Created by Alexandre Frigon on 2018-10-25.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

class Conductor: GuardStatus {
    private let nes = NintendoEntertainmentSystem()
    private let imageGenerator = ImageGenerator()
    private let renderer: Renderer
    private let loop: LogicLoop

    var status: String {
        return """
        \(self.loop.status)
        \(self.nes.status)
        """
    }
    
    init(with renderer: Renderer, drivenBy loop: LogicLoop) {
        self.renderer = renderer
        self.loop = loop
        self.loop.start(closure: self.loopClosure)
    }
    
    private func loopClosure(_ deltaTime: Double) {
        self.processInput()
        self.update(deltaTime)
        self.render()
    }
    
    private func processInput() {
        
    }
    
    private func update(_ deltaTime: Double) {
        // self.nes cycle some stuff
    }
    
    private func render() {
        let image: [Byte] = self.imageGenerator.generate()
        self.renderer.draw(image)
    }
}
