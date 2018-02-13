import React from 'react';
import './ClanTile.css';
import DynamicComponent from '../DynamicComponent';
import endpoints from '../endpoints';
import {Link} from 'react-router-dom';

class ClanTile extends DynamicComponent {
    getEndpoints(props) {
        return {"clan": endpoints.clan(props.clantag)}
    }

    render() {
        if (!this.isAllDynamicDataLoaded())
            return <div className="ClanTile">{this.getLoadingDynamicContent()}</div>;

        let clan = this.getDynamicData("clan");
        let membersString = (clan.members.length == 1 ? "member" : "members");

        let badge;
        if (clan.badgeURL) {
            badge = <img src={clan.badgeURL} alt={this.props.clantag + " badge"}/>;
        }

        return (
            <div className={"ClanTile " + (badge ? "_withBadge" : "")}>
                <Link to={"/clan/"+this.props.clantag}>
                    <div className="_clanHeader">
                        {this.props.clantag}
                    </div>
                    <div className="_clanNumMembers">
                        {clan.members.length} {membersString}
                    </div>
                    <div className="_badgeBox">
                        {badge}
                    </div>
                </Link>
            </div>
        );
    }
}

export default ClanTile;
