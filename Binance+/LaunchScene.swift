//
//  LaunchScene.swift
//  Binance+
//
//  Created by Behnam Karimi on 1/29/1398 AP.
//  Copyright © 1398 AP Behnam Karimi. All rights reserved.
//

import SpriteKit

class LaunchScene: SKScene {
    private let d: Double = 0.1 // anim duration

    private let icons = ["eth", "ltc", "bnb", "neo", "qtum", "eos", "snt", "bnt", "bcc", "gas", "btc", "hsr", "oax", "dnt", "mco", "icn", "wtc", "lrc", "omg", "zrx", "strat", "sngls", "knc", "fun", "snm", "link", "xvg", "salt", "mda", "mtl", "sub", "etc", "mth", "eng", "zec", "ast", "dash", "btg", "evx", "req", "vib", "trx", "powr", "ark", "xrp", "mod", "enj", "storj", "kmd", "nuls", "rcn", "rdn", "xmr", "dlt", "amb", "bat", "bcpt", "arn", "gvt", "cdt", "gxs", "poe", "qsp", "bts", "xzc", "lsk", "tnt", "fuel", "mana", "bcd", "dgd", "adx", "ada", "ppt", "cmt", "xlm", "cnd", "lend", "wabi", "tnb", "waves", "gto", "icx", "ost", "elf", "aion", "nebl", "brd", "edo", "wings", "nav", "lun", "trig", "appc", "vibe", "rlc", "ins", "pivx", "iost", "chat", "steem", "nano", "via", "blz", "ae", "rpx", "ncash", "poa", "zil", "ont", "storm", "xem", "wan", "wpr", "qlc", "sys", "grs", "cloak", "gnt", "loom", "bcn", "rep", "tusd", "zen", "sky", "cvc", "theta", "iotx", "agi", "nxs", "data", "sc", "npxs", "nas", "dent", "ardr", "hot", "vet", "dock", "poly", "pax", "rvn", "dcr", "usdc", "mith", "btt", "ong"] // count = 147
    
    
    
    
    
    
    //MARK: Show scene
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint.zero
        
        let w = view.frame.width
        let h = view.frame.height
        
        let txtr = SKTexture(image: Util.createGradientImage(color1: .white, color2: UIColor.fromHex(hex: "#FFD700"), width: w, height: h))
        let bg = SKSpriteNode(texture: txtr)
        bg.position = CGPoint(x: w / 2, y: h / 2)
        bg.size = CGSize(width: w, height: h)
        bg.zPosition = 0
        addChild(bg)
        
        
        
        let imW = w / CGFloat(8)
        let imH = imW
        
        var N = Int((h / imH) * (w / imW))
        if N > icons.count {
            N = icons.count
        }

        let animIndices = (0..<N).shuffled()
        
        for i in 0..<N {
            let n = SKSpriteNode(imageNamed: icons[i] + ".png")
            n.size = CGSize(width: imW, height: imH)
            n.position = CGPoint(x: imW / 2 + CGFloat(i % 8) * imW, y: imH / 2 + CGFloat(i / 8) * imH)
            n.alpha = 0.0
            n.zPosition = 1.0
            addChild(n)
            let animIndex = animIndices[i]
            let waitAction = SKAction.wait(forDuration: Double(animIndex) * d)
            let fadeAction = SKAction.fadeAlpha(to: 1.0 - n.alpha, duration: d)
            n.run(SKAction.sequence([waitAction, fadeAction]))
        }
        
        
    }
    
    
    
    
    
    private func label(text: String, color: UIColor, size: CGFloat, position: CGPoint, hAlignment: SKLabelHorizontalAlignmentMode, vAlignment: SKLabelVerticalAlignmentMode) -> SKLabelNode {
        let l = SKLabelNode(fontNamed: "Menlo")
        l.text = text
        l.fontColor = color
        l.fontSize = size
        l.position = position
        l.verticalAlignmentMode = .center
        l.horizontalAlignmentMode = .center
        return l
    }
}
