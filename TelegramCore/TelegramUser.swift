import Foundation
#if os(macOS)
    import PostboxMac
#else
    import Postbox
#endif

public struct UserInfoFlags: OptionSet {
    public var rawValue: Int32
    
    public init() {
        self.rawValue = 0
    }
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    public static let isVerified = UserInfoFlags(rawValue: (1 << 0))
}

public struct BotUserInfoFlags: OptionSet {
    public var rawValue: Int32
    
    public init() {
        self.rawValue = 0
    }
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    public static let hasAccessToChatHistory = BotUserInfoFlags(rawValue: (1 << 0))
    public static let worksWithGroups = BotUserInfoFlags(rawValue: (1 << 1))
    public static let requiresGeolocationForInlineRequests = BotUserInfoFlags(rawValue: (1 << 2))
}

public struct BotUserInfo: PostboxCoding, Equatable {
    public let flags: BotUserInfoFlags
    public let inlinePlaceholder: String?
    
    init(flags: BotUserInfoFlags, inlinePlaceholder: String?) {
        self.flags = flags
        self.inlinePlaceholder = inlinePlaceholder
    }
    
    public init(decoder: PostboxDecoder) {
        self.flags = BotUserInfoFlags(rawValue: decoder.decodeInt32ForKey("f", orElse: 0))
        self.inlinePlaceholder = decoder.decodeOptionalStringForKey("ip")
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.flags.rawValue, forKey: "f")
        if let inlinePlaceholder = self.inlinePlaceholder {
            encoder.encodeString(inlinePlaceholder, forKey: "ip")
        } else {
            encoder.encodeNil(forKey: "ip")
        }
    }
    
    public static func ==(lhs: BotUserInfo, rhs: BotUserInfo) -> Bool {
        return lhs.flags == rhs.flags && lhs.inlinePlaceholder == rhs.inlinePlaceholder
    }
}

public final class TelegramUser: Peer {
    public let id: PeerId
    public let accessHash: Int64?
    public let firstName: String?
    public let lastName: String?
    public let username: String?
    public let phone: String?
    public let photo: [TelegramMediaImageRepresentation]
    public let botInfo: BotUserInfo?
    public let flags: UserInfoFlags
    
    public var name: String {
        if let firstName = self.firstName {
            if let lastName = self.lastName {
                return "\(firstName) \(lastName)"
            } else {
                return firstName
            }
        } else if let lastName = self.lastName {
            return lastName
        } else {
            return ""
        }
    }
    
    public var indexName: PeerIndexNameRepresentation {
        return .personName(first: self.firstName ?? "", last: self.lastName ?? "", addressName: self.username, phoneNumber: self.phone)
    }
    
    public let associatedPeerId: PeerId? = nil
    public let notificationSettingsPeerId: PeerId? = nil
    
    public init(id: PeerId, accessHash: Int64?, firstName: String?, lastName: String?, username: String?, phone: String?, photo: [TelegramMediaImageRepresentation], botInfo: BotUserInfo?, flags: UserInfoFlags) {
        self.id = id
        self.accessHash = accessHash
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.phone = phone
        self.photo = photo
        self.botInfo = botInfo
        self.flags = flags
    }
    
    public init(decoder: PostboxDecoder) {
        self.id = PeerId(decoder.decodeInt64ForKey("i", orElse: 0))
        
        let accessHash: Int64 = decoder.decodeInt64ForKey("ah", orElse: 0)
        if accessHash != 0 {
            self.accessHash = accessHash
        } else {
            self.accessHash = nil
        }
        
        self.firstName = decoder.decodeOptionalStringForKey("fn")
        self.lastName = decoder.decodeOptionalStringForKey("ln")
        
        self.username = decoder.decodeOptionalStringForKey("un")
        self.phone = decoder.decodeOptionalStringForKey("p")
        
        self.photo = decoder.decodeObjectArrayForKey("ph")
        
        if let botInfo = decoder.decodeObjectForKey("bi", decoder: { return BotUserInfo(decoder: $0) }) as? BotUserInfo {
            self.botInfo = botInfo
        } else {
            self.botInfo = nil
        }
        
        self.flags = UserInfoFlags(rawValue: decoder.decodeInt32ForKey("fl", orElse: 0))
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt64(self.id.toInt64(), forKey: "i")
        
        if let accessHash = self.accessHash {
            encoder.encodeInt64(accessHash, forKey: "ah")
        }
        
        if let firstName = self.firstName {
            encoder.encodeString(firstName, forKey: "fn")
        }
        if let lastName = self.lastName {
            encoder.encodeString(lastName, forKey: "ln")
        }
        
        if let username = self.username {
            encoder.encodeString(username, forKey: "un")
        }
        if let phone = self.phone {
            encoder.encodeString(phone, forKey: "p")
        }
        
        encoder.encodeObjectArray(self.photo, forKey: "ph")
        
        if let botInfo = self.botInfo {
            encoder.encodeObject(botInfo, forKey: "bi")
        } else {
            encoder.encodeNil(forKey: "bi")
        }
        
        encoder.encodeInt32(self.flags.rawValue, forKey: "fl")
    }
    
    public func isEqual(_ other: Peer) -> Bool {
        if let other = other as? TelegramUser {
            if self.id != other.id {
                return false
            }
            if self.accessHash != other.accessHash {
                return false
            }
            if self.firstName != other.firstName {
                return false
            }
            if self.lastName != other.lastName {
                return false
            }
            if self.phone != other.phone {
                return false
            }
            if self.photo.count != other.photo.count {
                return false
            }
            for i in 0 ..< self.photo.count {
                if self.photo[i] != other.photo[i] {
                    return false
                }
            }
            if self.botInfo != other.botInfo {
                return false
            }
            
            if self.flags != other.flags {
                return false
            }
            
            return true
        } else {
            return false
        }
    }
    
    func withUpdatedUsername(_ username:String?) -> TelegramUser {
        return TelegramUser(id: self.id, accessHash: self.accessHash, firstName: self.firstName, lastName: self.lastName, username: username, phone: self.phone, photo: self.photo, botInfo: self.botInfo, flags: self.flags)
    }
    
    func withUpdatedNames(firstName: String?, lastName: String?) -> TelegramUser {
        return TelegramUser(id: self.id, accessHash: self.accessHash, firstName: firstName, lastName: lastName, username: self.username, phone: self.phone, photo: self.photo, botInfo: self.botInfo, flags: self.flags)
    }
    
    func withUpdatedPhone(_ phone: String) -> TelegramUser {
        return TelegramUser(id: self.id, accessHash: self.accessHash, firstName: self.firstName, lastName: self.lastName, username: self.username, phone: phone, photo: self.photo, botInfo: self.botInfo, flags: self.flags)
    }
    
    func withUpdatedPhoto(_ representations: [TelegramMediaImageRepresentation]) -> TelegramUser {
        return TelegramUser(id: self.id, accessHash: self.accessHash, firstName: self.firstName, lastName: self.lastName, username: self.username, phone: phone, photo: representations, botInfo: self.botInfo, flags: self.flags)
    }
}

func parsedTelegramProfilePhoto(_ photo: Api.UserProfilePhoto?) -> [TelegramMediaImageRepresentation] {
    var telegramPhoto: [TelegramMediaImageRepresentation] = []
    if let photo = photo {
        switch photo {
            case let .userProfilePhoto(_, photoSmall, photoBig):
                if let smallResource = mediaResourceFromApiFileLocation(photoSmall, size: nil), let largeResource = mediaResourceFromApiFileLocation(photoBig, size: nil) {
                    telegramPhoto.append(TelegramMediaImageRepresentation(dimensions: CGSize(width: 80.0, height: 80.0), resource: smallResource))
                    telegramPhoto.append(TelegramMediaImageRepresentation(dimensions: CGSize(width: 640.0, height: 640.0), resource: largeResource))
                }
            case .userProfilePhotoEmpty:
                break
        }
    }
    return telegramPhoto
}

public extension TelegramUser {
    public convenience init(user: Api.User) {
        switch user {
        case let .user(flags, id, accessHash, firstName, lastName, username, phone, photo, _, _, _, botInlinePlaceholder, _):
            var telegramPhoto: [TelegramMediaImageRepresentation] = []
            if let photo = photo {
                switch photo {
                case let .userProfilePhoto(_, photoSmall, photoBig):
                    if let smallResource = mediaResourceFromApiFileLocation(photoSmall, size: nil), let largeResource = mediaResourceFromApiFileLocation(photoBig, size: nil) {
                        telegramPhoto.append(TelegramMediaImageRepresentation(dimensions: CGSize(width: 80.0, height: 80.0), resource: smallResource))
                        telegramPhoto.append(TelegramMediaImageRepresentation(dimensions: CGSize(width: 640.0, height: 640.0), resource: largeResource))
                    }
                case .userProfilePhotoEmpty:
                    break
                }
            }
            
            var userFlags: UserInfoFlags = []
            if (flags & (1 << 17)) != 0 {
                userFlags.insert(.isVerified)
            }
            
            var botInfo: BotUserInfo?
            if (flags & (1 << 14)) != 0 {
                var botFlags = BotUserInfoFlags()
                if (flags & (1 << 15)) != 0 {
                    botFlags.insert(.hasAccessToChatHistory)
                }
                if (flags & (1 << 16)) == 0 {
                    botFlags.insert(.worksWithGroups)
                }
                if (flags & (1 << 21)) == 0 {
                    botFlags.insert(.requiresGeolocationForInlineRequests)
                }
                botInfo = BotUserInfo(flags: botFlags, inlinePlaceholder: botInlinePlaceholder)
            }
            self.init(id: PeerId(namespace: Namespaces.Peer.CloudUser, id: id), accessHash: accessHash, firstName: firstName, lastName: lastName, username: username, phone: phone, photo: telegramPhoto, botInfo: botInfo, flags: userFlags)
        case let .userEmpty(id):
            self.init(id: PeerId(namespace: Namespaces.Peer.CloudUser, id: id), accessHash: nil, firstName: nil, lastName: nil, username: nil, phone: nil, photo: [], botInfo: nil, flags: [])
        }
    }
    
    public static func merge(_ lhs: TelegramUser?, rhs: Api.User) -> TelegramUser? {
        switch rhs {
            case let .user(flags, _, accessHash, _, _, username, _, photo, _, _, _, botInlinePlaceholder, _):
                if let _ = accessHash {
                    return TelegramUser(user: rhs)
                } else {
                    let telegramPhoto = parsedTelegramProfilePhoto(photo)
                    if let lhs = lhs {
                        var userFlags: UserInfoFlags = []
                        if (flags & (1 << 17)) != 0 {
                            userFlags.insert(.isVerified)
                        }
                        
                        var botInfo: BotUserInfo?
                        if (flags & (1 << 14)) != 0 {
                            var botFlags = BotUserInfoFlags()
                            if (flags & (1 << 15)) != 0 {
                                botFlags.insert(.hasAccessToChatHistory)
                            }
                            if (flags & (1 << 16)) == 0 {
                                botFlags.insert(.worksWithGroups)
                            }
                            if (flags & (1 << 21)) == 0 {
                                botFlags.insert(.requiresGeolocationForInlineRequests)
                            }
                            botInfo = BotUserInfo(flags: botFlags, inlinePlaceholder: botInlinePlaceholder)
                        }
                        
                        return TelegramUser(id: lhs.id, accessHash: lhs.accessHash, firstName: lhs.firstName, lastName: lhs.lastName, username: username, phone: lhs.phone, photo: telegramPhoto, botInfo: botInfo, flags: userFlags)
                    } else {
                        return TelegramUser(user: rhs)
                    }
                }
            case .userEmpty:
                return TelegramUser(user: rhs)
        }
    }
    

}
