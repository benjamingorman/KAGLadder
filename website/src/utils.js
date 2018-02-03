export function getValidKagClasses() {
    return ["knight", "archer", "builder"];
}

export function capitalizeString(s) {
    return s.charAt(0).toUpperCase() + s.slice(1);
}

export function genderToString(n) {
    if (n == 0)
        return "Male";
    else if (n == 1)
        return "Female";
    else {
        console.warn("genderToString: ERROR unrecognized gender", n);
        return "Male";
    }
}

export function getTitleFromRating(rat) {
    if (rat >= 2600) {
        return "Legendary";
    }
    else if (rat >= 2200) {
        return "Grand-master";
    }
    else if (rat >= 2000) {
        return "Master";
    }
    else if (rat >= 1800) {
        return "Diamond";
    }
    else if (rat >= 1600) {
        return "Platinum";
    }
    else if (rat >= 1400) {
        return "Gold";
    }
    else if (rat >= 1200) {
        return "Silver";
    }
    else if (rat >= 1000) {
        return "Bronze";
    }
    else {
        return "Peasant";
    }
}
