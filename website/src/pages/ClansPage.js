import React from 'react';
import { Link } from 'react-router-dom';
import './ClansPage.css';
import Page from './Page';
import DynamicComponent from '../DynamicComponent';
import endpoints from '../endpoints';
import _ from 'lodash';

class ClansPage extends DynamicComponent {
    getEndpoints() {
        return {"clans": endpoints.clans};
    }

    render() {
        if (!this.isAllDynamicDataLoaded())
            return this.getLoadingDynamicContent();

        let clansRows = [];
        let clansData = _.sortBy(this.getDynamicData("clans"), (c) => -c.members.length);
        let k = 0;

        for (let clanObj of clansData) {
            let clan = clanObj.clan;
            let members = clanObj.members;

            let membersRows = [];
            for (let member of members) {
                membersRows.push(
                    <li key={k++}>
                        <Link to={"/player/"+member}>{member}</Link>
                    </li>
                    );
            }

            clansRows.push(
                <div key={k++} className="_clan box">
                    <div className="_box_label">
                        {clan}
                    </div>
                    <h3>{members.length} members</h3>
                    <ul>{membersRows}</ul>
                </div>
                );
        }

        return (
            <div className="ClansPage">
                <Page title="Clans">
                    {clansRows}
                </Page>
            </div>
        );
    }
}
export default ClansPage;
