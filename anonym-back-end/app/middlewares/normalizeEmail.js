function normalizeEmail(req, res, next) {
    const gmailDomains = ['gmail.com', 'googlemail.com'];
    
    if (req.body.email) {
        const [localPart, domainPart] = req.body.email.split('@');
        if (gmailDomains.includes(domainPart.toLowerCase())) {
            req.body.email = localPart.replace(/\./g, '') + '@' + domainPart;
        }
    } else if(req.body.identifier) {
        const [localPart, domainPart] = req.body.identifier.split('@');
        if (domainPart && gmailDomains.includes(domainPart.toLowerCase())) {
            req.body.identifier = localPart.replace(/\./g, '') + '@' + domainPart;
        }
    }
    next();
}

module.exports = normalizeEmail;