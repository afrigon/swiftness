//
//  Created by Alexandre Frigon on 2018-10-25.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

class Conductor {
    let renderer: Renderer
    let loop: LogicLoop
    let imageGenerator = ImageGenerator()
    let nes = NintendoEntertainmentSystem()
    
    init(with renderer: Renderer, drivenBy loop: LogicLoop) {
        self.renderer = renderer
        self.loop = loop
        self.loop.start(closure: self.loopClosure)
    }
    
    func loopClosure(_ deltaTime: Double) {
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
