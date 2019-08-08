//
//  DivvunSpellBannerPlugin.swift
//  BaseKeyboard
//
//  Created by Brendan Molloy on 2019-08-08.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation
import Sentry

class SuggestionOp: Operation {
    weak var plugin: DivvunSpellBannerPlugin?
    let word: String
    
    init (plugin: DivvunSpellBannerPlugin, word: String) {
        self.plugin = plugin
        self.word = word
    }
    
    override func main() {
        if (isCancelled) {
            return
        }
        
        guard let plugin = self.plugin else { return }
        guard let speller = plugin.speller else { return }
        
        let suggestions = speller
            .suggest(word: self.word, count: 3, maxWeight: 4999.99)
            .map({ BannerItem(title: $0, value: "suggestion") })
        
        if !isCancelled {
            DispatchQueue.main.async {
                plugin.banner.isHidden = false
                plugin.banner.items = suggestions
            }
        }
    }
}

extension DivvunSpellBannerPlugin: BannerViewDelegate {
    public func textInputDidChange(_ banner: BannerView, context: CursorContext) {
        print(context)
        
        if context.currentWord == "" {
            banner.items = []
            return
        }
        
        opQueue.cancelAllOperations()
        opQueue.addOperation(SuggestionOp(plugin: self, word: context.currentWord))
    }
    
    public func didSelectBannerItem(_ banner: BannerView, item: BannerItem) {
        if let value = item.value as? String, value == "error" {
            banner.items = []
            banner.isHidden = true
            return
        }
        
        keyboard.replaceSelected(with: item.title)
    }
}

public class DivvunSpellBannerPlugin {
    unowned let banner: BannerView
    unowned let keyboard: KeyboardViewController
    
    fileprivate var speller: ChfstSpeller? = nil
    
    let opQueue: OperationQueue = {
        let o = OperationQueue()
        o.underlyingQueue = DispatchQueue.global(qos: .userInteractive)
        o.maxConcurrentOperationCount = 1
        return o
    }()
    
    private func getPrimaryLanguage() -> String? {
        if let ex = Bundle.main.infoDictionary!["NSExtension"] as? [String: AnyObject]{
            if let attrs = ex["NSExtensionAttributes"] as? [String: AnyObject] {
                if let lang = attrs["PrimaryLanguage"] as? String {
                    return String(lang.split(separator: "_")[0])
                }
            }
        }
        
        return nil
    }
    
    private func loadZHFST() {
        print("Loading speller…")
        
        DispatchQueue.global(qos: .background).async {
            print("Dispatching request to load speller…")
            
            let sentryEvent = Sentry.Event(level: .debug)
            
            guard let bundle = Bundle.top.url(forResource: "dicts", withExtension: "bundle") else {
                sentryEvent.message = "No dict bundle found; ZHFST not loaded."
                Client.shared?.send(event: sentryEvent, completion: nil)
                print("No dict bundle found; ZHFST not loaded.")
                return
            }
            
            guard let lang = self.getPrimaryLanguage() else {
                sentryEvent.message = "No primary language found for keyboard; ZHFST not loaded."
                Client.shared?.send(event: sentryEvent, completion: nil)
                print("No primary language found for keyboard; ZHFST not loaded.")
                return
            }
            
            let path = bundle.appendingPathComponent("\(lang).chfst")
            
            if !FileManager.default.fileExists(atPath: path.path) {
                sentryEvent.message = "No speller at: \(path)"
                Client.shared?.send(event: sentryEvent, completion: nil)
                print("No speller at: \(path)")
                print("DivvunSpell **not** loaded.")
                return
            }
            
            let speller: ChfstSpeller
            
            do {
                speller = try ChfstSpeller(path: path)
            } catch {
                let e = Sentry.Event(level: .error)
                if let error = error as? SpellerInitError {
                    e.message = error.message
                    print(error.message)
                    DispatchQueue.main.async {
                        self.banner.items = [BannerItem(title: "Speller could not load. Tap to hide.", value: "error")]
                    }
                } else {
                    e.message = error.localizedDescription
                }
                Client.shared?.send(event: e, completion: nil)
                print("DivvunSpell **not** loaded.")
                return
            }
            
            print("DivvunSpell loaded!")
            
            self.speller = speller
        }
    }
    
    public init(keyboard: KeyboardViewController) {
        self.keyboard = keyboard
        self.banner = keyboard.bannerView
        
        banner.delegate = self
        loadZHFST()
    }
}
