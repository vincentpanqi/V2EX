import Foundation
import Kanna

protocol HTMLParseService {
    func parseTopic(rootPath: XPathObject) -> [TopicModel]
    func parseNodeNavigation(html: HTMLDocument) -> [NodeCategoryModel]
    func replacingIframe(text: String) -> String
    func parseOnce(html: HTMLDocument) -> String?
}

extension HTMLParseService {
    
    
    /// 解析主题列表
    ///
    /// - Parameter html: HTMLDoc
    /// - Returns: topic model
    func parseTopic(rootPath: XPathObject) -> [TopicModel] {
        
        //        let itemPath = html.xpath("//*[@id='Wrapper']/div[@class='box']/div[@class='cell item']")

        let topics = rootPath.flatMap({ ele -> TopicModel? in
            guard let userPage = ele.xpath(".//td/a").first?["href"],
                let avatarSrc = ele.xpath(".//td/a/img").first?["src"],
                let topicPath = ele.xpath(".//td/span[@class='item_title']/a").first,
                let topicTitle = topicPath.content,
                let topicHref = topicPath["href"],
                let username = ele.xpath(".//td/span[@class='small fade']/strong[1]").first?.content else {
                    return nil
            }

            
            let replyCount = Int(ele.xpath(".//td/a[@class='count_livid']").first?.content ?? "0") ?? 0
            var lastReplyTime: String?
            if let subs = ele.xpath(".//td/span[@class='small fade']").first?.text?.components(separatedBy: "•"), subs.count > 2 {
                lastReplyTime = subs[2].trimmed
            }


            let user = MemberModel(username: username, url: userPage, avatar: avatarSrc)
            
            var node: NodeModel?
            
            if let nodePath = ele.xpath(".//td/span[@class='small fade']/a[@class='node']").first,
                let nodename = nodePath.content,
                let nodeHref = nodePath["href"] {
                node = NodeModel(name: nodename, href: nodeHref)
            }

            return TopicModel(user: user, node: node, title: topicTitle, href: topicHref, lastReplyTime: lastReplyTime, replyCount: replyCount)
        })
        
        return topics
    }
    
    func parseNodeNavigation(html: HTMLDocument) -> [NodeCategoryModel] {
        let nodesPath = html.xpath("//*[@id='Wrapper']//div[@class='box'][last()]/div/table/tr")
        
        ////        var nodeCategorys: [NodeCategoryModel] = []
        //        for (index, ele) in nodesPath.enumerated() {
        //            guard let sectionName = ele.xpath("./td[1]/span").first?.content else { continue }
        //
        //            let nodes = ele.xpath("./td[2]/a").flatMap({ (ele) -> NodeModel? in
        //                guard let name = ele.content, let href = ele["href"] else { return nil }
        //                return NodeModel(name: name, href: href)
        //            })
        //            NodeCategoryStore.shared.deleteAll()
        //            NodeStore.shared.deleteAll()
        //            let category = NodeCategoryModel(id: index, name: sectionName, nodes: nodes)
        //            NodeCategoryStore.shared.insert(category)
        ////            nodeCategorys.append(category)
        //        }
        let nodeCategorys = nodesPath.flatMap { (ele) -> NodeCategoryModel? in
            
            guard let sectionName = ele.xpath("./td[1]/span").first?.content else { return nil }
            
            let nodes = ele.xpath("./td[2]/a").flatMap({ (ele) -> NodeModel? in
                guard let name = ele.content, let href = ele["href"] else { return nil }
                
                return NodeModel(name: name, href: href)
            })
            return NodeCategoryModel(id: 0, name: sectionName, nodes: nodes)
        }
        return nodeCategorys
    }


    // MARK: - 评论里面的视频替换成链接地址
    func replacingIframe(text: String) -> String {
        guard text.contains("</iframe>") else { return text }
        let pattern = "<iframe(.*?)</iframe>"
        let regx = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        guard let results = regx?.matches(in: text, options: .reportProgress, range: NSRange(location: 0, length: text.count)) else {
            return text
        }

        var content = text
        results.forEach {result in
            if let range = result.range.range(for: text) {
                let iframe = text[range]
                let arr = iframe.components(separatedBy: " ")
                if let srcIndex = arr.index(where: {$0.contains("src")}) {
                    let srcText = arr[srcIndex]
                    let href = srcText.replacingOccurrences(of: "src", with: "href")
                    let urlString = srcText.replacingOccurrences(of: "src=", with: "").replacingOccurrences(of: "\"", with: "")
                    let a = "<a \(href)>\(urlString)</a>"
                    content = text.replacingOccurrences(of: iframe, with: a)
                }
            }
        }
        return content
    }

    func parseOnce(html: HTMLDocument) -> String? {
        return html.xpath("//input[@name='once']").first?["value"]
    }
}
