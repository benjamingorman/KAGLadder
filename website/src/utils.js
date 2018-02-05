export function getValidKagClasses() {
    return ["knight", "archer", "builder"];
}

export function formatRatingChange(r) {
    if (r >= 0) {
        return "+" + r + " rating";
    }
    else {
        return "" + r + " rating";
    }
}

export function unixTimeToDateAndTime(ut) {
    let t = new Date();
    t.setTime(ut * 1000);
    let dateString = t.toLocaleDateString();
    let timeString = t.toLocaleTimeString();
    return [dateString, timeString];
}

export function getValidRegions() {
    return ["EU", "US", "AUS"];
}

export function capitalizeString(s) {
    return s.charAt(0).toUpperCase() + s.slice(1);
}

export function genderToString(n) {
    if (n === 0)
        return "Male";
    else if (n === 1)
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
